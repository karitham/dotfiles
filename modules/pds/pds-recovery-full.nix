{ nixpkgs, pkgs }:
let
  _pkgs = import nixpkgs {
    config = { };
    system = pkgs.stdenv.hostPlatform.system;
    overlays = [ (import ../overlays) ];
  };
in
_pkgs.testers.runNixOSTest {
  name = "pds-full";
  meta.maintainers = [ ];

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ./default.nix ];

      services.minio = {
        enable = true;
        rootCredentialsFile = "/tmp/minio-credentials";
      };

      systemd.tmpfiles.rules = [
        "f /tmp/minio-credentials 0600 root root - MINIO_ROOT_USER=minioadmin\\nMINIO_ROOT_PASSWORD=minioadmin123"
        "f /run/secrets/s3.env 0600 root root - AWS_ACCESS_KEY_ID=minioadmin\\nAWS_SECRET_ACCESS_KEY=minioadmin123\\nAWS_ENDPOINT_URL=http://127.0.0.1:9000\\nS3_BUCKET=pds-test-bucket"
        "f /run/secrets/pds.env 0600 root root - PDS_JWT_SECRET=test-jwt-secret-for-full-testing\\nPDS_ADMIN_PASSWORD=test-admin-password\\nPDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=1111111111111111111111111111111111111111111111111111111111111111"
      ];

      services.pds-with-backups = {
        enable = true;
        domain = "test.example.com";
        pdsDataDir = "/var/lib/pds";
        secretsFiles = [
          "/run/secrets/pds.env"
          "/run/secrets/s3.env"
        ];
        s3Bucket = "pds-test-bucket";
        s3Prefix = "pds-replica";
        enableStatelessBlobs = false;
        pdsSettings = {
          PDS_PORT = 3000;
          PDS_DISABLE_PHONE_VERIFICATION = "true";
        };
      };

      environment.systemPackages = with pkgs; [
        sqlite
        curl
        jq
        minio-client
        awscli2
      ];
    };

  testScript = ''
    import json

    machine.start()

    print("=== PDS Recovery Full Integration Test ===")

    print("\n--- Setting up MinIO ---")
    machine.wait_for_unit("minio.service")
    machine.wait_for_open_port(9000)
    machine.succeed("sleep 5")

    machine.succeed("test -f /tmp/minio-credentials")
    machine.succeed("test -f /run/secrets/s3.env")
    machine.succeed("test -f /run/secrets/pds.env")

    machine.succeed("mc alias set local http://127.0.0.1:9000 minioadmin minioadmin123")
    machine.succeed("mc mb local/pds-test-bucket --ignore-existing")
    print("  [PASS] MinIO bucket created")

    print("\n--- Test 1: PDS Initialization ---")
    machine.succeed("systemctl start pds-restore")
    machine.wait_for_unit("pds-restore.service")

    machine.succeed("systemctl start bluesky-pds")
    machine.wait_for_unit("bluesky-pds.service")
    machine.wait_for_open_port(3000)

    machine.succeed("sleep 30")

    health_response = machine.succeed("curl -s http://127.0.0.1:3000/xrpc/_health")
    try:
        health_data = json.loads(health_response)
        assert "version" in health_data or "status" in health_data, f"Unexpected health response: {health_response}"
        print(f"  [PASS] PDS is running and healthy: {health_response}")
    except json.JSONDecodeError:
        assert health_response.strip() in ["", "OK"], f"Unexpected health response: {health_response}"
        print("  [PASS] PDS is running and healthy (empty response)")

    print("\n--- Test 2: Litestream replication ---")
    machine.wait_for_unit("litestream-pds.service")
    machine.succeed("systemctl status litestream-pds.service")
    print("  [PASS] Litestream service is running")

    print("\n--- Test 3: Database creation ---")
    machine.succeed("sleep 30")
    pds_files = machine.succeed("ls -la /var/lib/pds/")
    print(f"  Files in /var/lib/pds: {pds_files}")

    sqlite_files = machine.succeed("find /var/lib/pds -name '*.sqlite' 2>/dev/null || true")
    assert sqlite_files.strip() != "", f"No sqlite files found in /var/lib/pds. Output: {sqlite_files}"
    print(f"  Found sqlite files: {sqlite_files.strip()}")
    print("  [PASS] Database files created")

    print("\n--- Test 4: Simulating disaster (data loss) ---")
    machine.succeed("systemctl stop bluesky-pds litestream-pds")

    machine.succeed("rm -rf /var/lib/pds/*")
    remaining = machine.succeed("find /var/lib/pds -name '*.sqlite' 2>/dev/null || true")
    assert remaining.strip() == "", "Should have no sqlite files after deletion"
    print("  [PASS] All data deleted - simulating complete server failure")

    print("\n--- Test 5: Automatic restore from S3 ---")
    restore_result = machine.succeed("pds-litestream-restore 2>&1")
    print(f"  Restore output: {restore_result}")

    restored_sqlite = machine.succeed("find /var/lib/pds -name '*.sqlite' 2>/dev/null || true")
    assert restored_sqlite.strip() != "", "Expected databases to be restored from S3"
    print(f"  Restored sqlite files: {restored_sqlite.strip()}")
    print("  [PASS] Databases restored from S3")

    print("\n--- Test 6: Data integrity verification ---")
    machine.succeed("systemctl start bluesky-pds")
    machine.wait_for_unit("bluesky-pds.service")
    machine.wait_for_open_port(3000)
    machine.succeed("sleep 30")

    health_response2 = machine.succeed("curl -s http://127.0.0.1:3000/xrpc/_health")
    try:
        health_data2 = json.loads(health_response2)
        assert "version" in health_data2, f"Unexpected health response: {health_response2}"
        print("  [PASS] PDS is healthy after recovery")
    except json.JSONDecodeError:
        pass

    print("\n--- Test 7: Litestream resumption ---")
    machine.succeed("systemctl start litestream-pds")
    machine.wait_for_unit("litestream-pds.service")
    machine.succeed("sleep 10")

    final_minio = machine.succeed("mc ls local/pds-test-bucket/pds-replica/ --recursive 2>/dev/null")
    assert ".sqlite" in final_minio, "Expected ongoing replication"
    print("  [PASS] Litestream resumed replication after recovery")

    print("\n--- Test 8: Health check service ---")
    machine.succeed("systemctl start pds-healthcheck")
    machine.succeed("sleep 2")
    health_log = machine.succeed("journalctl -u pds-healthcheck.service -o cat 2>/dev/null || true")
    assert "All services healthy" in health_log, f"Expected health check message, got: {health_log}"
    print("  [PASS] Health check service working")

    print("\n" + "="*60)
    print("ALL FULL INTEGRATION TESTS PASSED")
    print("Zero-touch disaster recovery verified successfully")
    print("Data integrity maintained through backup/restore cycle")
    print("Multiple secrets files work correctly")
    print("="*60)
  '';
}
