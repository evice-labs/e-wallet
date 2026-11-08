{
  description = "Evice Wallet UI Plugin for Logos Basecamp";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder";
    e_wallet_core.url = "github:evice-labs/e-wallet-core";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    let
      moduleOutputs = logos-module-builder.lib.mkLogosQmlModule {
        src = ./.;
        configFile = ./metadata.json;
        flakeInputs = inputs;
      };
      nixpkgs = logos-module-builder.inputs.nixpkgs;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      extraChecks = nixpkgs.lib.genAttrs supportedSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          qmllint = pkgs.runCommand "qmllint-check" {
            nativeBuildInputs = [ pkgs.qt6.qtdeclarative ];
          } ''
            for file in $(find ${./qml} -name "*.qml" | sort); do
              qmllint -I ${./qml/controls} -I ${./qml/theme} -I ${./qml/modals} -I ${./qml/views} -I ${./qml/state} "$file"
            done
            touch $out
          '';

          qmlformat = pkgs.runCommand "qmlformat-check" {
            nativeBuildInputs = [ pkgs.qt6.qtdeclarative pkgs.diffutils ];
          } ''
            mkdir -p src
            cp -r ${./qml} src/qml
            chmod -R u+w src
            for file in $(find src/qml -name "*.qml" | sort); do
              qmlformat "$file" > "$file.fmt"
              diff -u "$file" "$file.fmt" || {
                echo "Error: $file is not formatted according to qmlformat."
                exit 1
              }
            done
            touch $out
          '';
        }
      );
    in
    moduleOutputs // {
      checks = nixpkgs.lib.recursiveUpdate moduleOutputs.checks extraChecks;
    };
}
