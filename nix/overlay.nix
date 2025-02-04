final: prev:
with final.haskell.lib;
{

  haskellPackages = prev.haskellPackages.override (old: {
    overrides = final.lib.composeExtensions (old.overrides or (_: _: { }))
      (
        self: super:
          let
            autodocodecPkg = name:
              buildFromSdist (overrideCabal (self.callPackage (../${name}/default.nix) { }) (old: {
                doBenchmark = true;
                configureFlags = (old.configureFlags or [ ]) ++ [
                  # Optimisations
                  "--ghc-options=-O2"
                  # Extra warnings
                  "--ghc-options=-Wall"
                  "--ghc-options=-Wincomplete-uni-patterns"
                  "--ghc-options=-Wincomplete-record-updates"
                  "--ghc-options=-Wpartial-fields"
                  "--ghc-options=-Widentities"
                  "--ghc-options=-Wredundant-constraints"
                  "--ghc-options=-Wcpp-undef"
                  "--ghc-options=-Werror"
                  "--ghc-options=-Wno-deprecations"
                ];
                # Ugly hack because we can't just add flags to the 'test' invocation.
                # Show test output as we go, instead of all at once afterwards.
                testTarget = (old.testTarget or "") + " --show-details=direct";
                # Turn off tests for older GHC's because they use aeson <=1.0
                # and that outputs different schemas so the tests would fail
                doCheck = final.lib.versionAtLeast self.ghc.version "9.2.7";
              }));

            autodocodecPackages = {
              autodocodec = autodocodecPkg "autodocodec";
              autodocodec-api-usage = autodocodecPkg "autodocodec-api-usage";
              autodocodec-openapi3 = autodocodecPkg "autodocodec-openapi3";
              autodocodec-schema = autodocodecPkg "autodocodec-schema";
              autodocodec-servant-multipart = autodocodecPkg "autodocodec-servant-multipart";
              autodocodec-swagger2 = autodocodecPkg "autodocodec-swagger2";
              autodocodec-yaml = autodocodecPkg "autodocodec-yaml";
            };
          in
          {
            inherit autodocodecPackages;

            autodocodecRelease =
              final.symlinkJoin {
                name = "autodocodec-release";
                paths = final.lib.attrValues self.autodocodecPackages;
              };

            openapi3 =
              if super.openapi3.meta.broken
              then dontCheck (unmarkBroken super.openapi3)
              else if final.lib.versionAtLeast super.openapi3.version "3.2.3"
              then final.lib.warn "Don't need this override openapi3 anymore." super.openapi3
              else super.openapi3;
          } // autodocodecPackages
      );
  });
}
