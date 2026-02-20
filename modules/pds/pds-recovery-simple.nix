{ nixpkgs, pkgs }:
let
  _pkgs = import nixpkgs {
    config = { };
    inherit (pkgs.stdenv.hostPlatform) system;
    overlays = [ (import ../overlays) ];
  };
in
_pkgs.testers.runNixOSTest {
  name = "pds-simple";
  meta.maintainers = [ ];

  nodes.machine =
    { pkgs, lib, ... }:
    {
      imports = [ ./nixos.nix ];

      services.pds-with-backups = {
        enable = true;
        secretsFiles = [
          "/run/secrets/pds.env"
          "/run/secrets/s3.env"
        ];
        backupS3Prefix = "test-pds";
        settings = {
          PDS_HOSTNAME = "example.com";
        };
      };

      systemd.tmpfiles.rules = [
        "f /run/secrets/pds.env 0644 pds pds - PDS_JWT_SECRET=test-jwt-secret\nPDS_ADMIN_PASSWORD=test-password\nPDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=0000000000000000000000000000000000000000000000000000000000000000"
        "f /run/secrets/s3.env 0644 pds pds - AWS_ACCESS_KEY_ID=test-key\nAWS_SECRET_ACCESS_KEY=test-secret\nAWS_ENDPOINT_URL=https://s3.test.example.com\nS3_BUCKET=test-bucket"
      ];

      services.bluesky-pds.enable = true;
      systemd.services.bluesky-pds.serviceConfig.ExecStart =
        lib.mkForce "${pkgs.coreutils}/bin/echo 'PDS mocked for testing'";

      environment.systemPackages = with pkgs; [
        sqlite
        coreutils
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    print("=== PDS Recovery Simple Configuration Tests ===")

    print("\n--- Test 1: Systemd service creation ---")
    services_to_check = [
      "/etc/systemd/system/pds-restore.service",
      "/etc/systemd/system/litestream-pds.service",
      "/etc/systemd/system/pds-healthcheck.timer"
    ]

    for service in services_to_check:
      machine.succeed(f"test -f {service}")
      print(f"  [PASS] {service} exists")

    print("\n--- Test 2: User and group creation ---")
    machine.succeed("getent passwd pds")
    machine.succeed("getent group pds")
    print("  [PASS] PDS user and group exist")

    print("\n--- Test 3: Directory creation ---")
    machine.succeed("test -d /var/lib/pds")
    machine.succeed("test -d /var/log/pds-backup")
    pds_dir_info = machine.succeed("stat -c '%U:%G %a' /var/lib/pds")
    assert "pds:pds" in pds_dir_info, f"Unexpected ownership: {pds_dir_info}"
    print("  [PASS] Directories created with correct permissions")

    print("\n--- Test 4: Secrets files ---")
    machine.succeed("test -f /run/secrets/pds.env")
    machine.succeed("test -f /run/secrets/s3.env")
    print("  [PASS] Secrets files exist")

    print("\n--- Test 5: Restore script availability ---")
    machine.succeed("which pds-litestream-restore")
    print("  [PASS] Restore script is available")

    print("\n--- Test 6: pds-restore service configuration ---")
    restore_config = machine.succeed("systemctl cat pds-restore.service")
    assert "Type=oneshot" in restore_config, "pds-restore should be oneshot"
    assert "RemainAfterExit=true" in restore_config, "pds-restore should remain after exit"
    assert "/run/secrets/pds.env" in restore_config, "Restore should use pds.env"
    assert "/run/secrets/s3.env" in restore_config, "Restore should use s3.env"
    print("  [PASS] pds-restore configured correctly")

    print("\n--- Test 7: litestream-pds service configuration ---")
    litestream_config = machine.succeed("systemctl cat litestream-pds.service")
    assert "User=pds" in litestream_config, "litestream should run as pds user"
    assert "Restart=on-failure" in litestream_config, "litestream should restart on failure"
    assert "/run/secrets/pds.env" in litestream_config, "Litestream should use pds.env"
    assert "/run/secrets/s3.env" in litestream_config, "Litestream should use s3.env"
    print("  [PASS] litestream-pds configured correctly")

    print("\n--- Test 8: PDS service dependencies ---")
    pds_config = machine.succeed("systemctl cat bluesky-pds.service")
    assert "pds-restore.service" in pds_config, "PDS should depend on restore service"
    print("  [PASS] PDS service correctly depends on restore")

    print("\n--- Test 9: Package dependencies ---")
    machine.succeed("which litestream")
    machine.succeed("which aws")
    print("  [PASS] Required packages are available")

    print("\n" + "="*60)
    print("ALL SIMPLE CONFIGURATION TESTS PASSED")
    print("="*60)
  '';
}
