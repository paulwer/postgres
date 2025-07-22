{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  postgresql,
  openssl,
  libkrb5,
}:

stdenv.mkDerivation rec {
  pname = "timescaledb";
  version = "2.21.0";

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    postgresql
    openssl
    libkrb5
  ];

  src = fetchFromGitHub {
    owner = "timescale";
    repo = "timescaledb";
    rev = version;
    hash = "sha256-t3BPy1rmV3f/OFDHqiRh1E9tNH7dc1LCTktvkSSZLro=";
  };

  cmakeFlags = [
    "-DSEND_TELEMETRY_DEFAULT=OFF"
    "-DREGRESS_CHECKS=OFF"
    "-DTAP_CHECKS=OFF"
  ] ++ lib.optionals stdenv.isDarwin [ "-DLINTER=OFF" ];

  # Fix the install phase which tries to install into the pgsql extension dir,
  # and cannot be manually overridden. This is rather fragile but works OK.
  postPatch = ''
    for x in CMakeLists.txt sql/CMakeLists.txt; do
      substituteInPlace "$x" \
        --replace 'DESTINATION "''${PG_SHAREDIR}/extension"' "DESTINATION \"$out/share/postgresql/extension\""
    done

    for x in src/CMakeLists.txt src/loader/CMakeLists.txt tsl/src/CMakeLists.txt; do
      substituteInPlace "$x" \
        --replace 'DESTINATION ''${PG_PKGLIBDIR}' "DESTINATION \"$out/lib\""
    done
  '';

  # timescaledb-2.9.1.so already exists in the lib directory
  # we have no need for the timescaledb.so or control file
  postInstall = ''
    rm $out/lib/timescaledb.so
    rm $out/share/postgresql/extension/timescaledb.control
  '';

  meta = with lib; {
    description = "Scales PostgreSQL for time-series data via automatic partitioning across time and space";
    homepage = "https://www.timescale.com/";
    changelog = "https://github.com/timescale/timescaledb/blob/${version}/CHANGELOG.md";
    platforms = postgresql.meta.platforms;
    license = licenses.tsl;
    broken = versionOlder postgresql.version "13";
  };
}
