{ lib, stdenv, fetchurl, coreutils, bash, mktemp, p7zip }:

stdenv.mkDerivation rec {
  pname = "knockknock";
  version = "3.1.0";
  
  src = fetchurl {
    url = "https://github.com/objective-see/KnockKnock/releases/download/v${version}/KnockKnock_${version}.zip";
    sha256 = "1xsj71gasnkpnwk9f4yk8c2ncqphr1dwbnah7rfc25986lp3jaha";
  };
  
  nativeBuildInputs = [ coreutils bash mktemp p7zip ];
  
  sourceRoot = ".";
  
  unpackPhase = ''
    mkdir -p $out/Applications
    
    echo "Extracting KnockKnock ZIP..."
    KNOCKKNOCK_TEMP=$(mktemp -d)
    
    ${p7zip}/bin/7z x "$src" -o"$KNOCKKNOCK_TEMP"
    
    echo "Installing KnockKnock.app..."
    find "$KNOCKKNOCK_TEMP" -name "*.app" -type d -exec cp -r {} $out/Applications/ \;
  '';
  
  installPhase = ''
    mkdir -p $out/bin
    
    echo "#!/bin/sh" > $out/bin/knockknock
    echo "open $out/Applications/KnockKnock.app" >> $out/bin/knockknock
    chmod +x $out/bin/knockknock
    
    echo "Installation complete"
  '';
  
  meta = with lib; {
    description = "KnockKnock is a tool to discover persistent items (e.g. malware) installed on macOS";
    homepage = "https://objective-see.org/products/knockknock.html";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = [];
  };
}