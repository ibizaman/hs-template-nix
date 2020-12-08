build:
	nix-shell --pure --run 'stack build'

test:
	nix-shell --pure --run 'stack test'

run:
	nix-shell --pure --run 'stack run'

hoogle-build:
	nix-shell --pure --run 'stack build --haddock --haddock-deps'

hoogle-generate:
	nix-shell --pure --run 'stack hoogle -- generate --quiet --local'

hoogle-serve:
	nix-shell --pure --run 'stack hoogle -- server --local --port=65000 --no-security-headers'

cachix-enable:
	cachix use ibizaman

cachix-push:
	nix-build | cachix push ibizaman
	nix-build shell.nix | cachix push ibizaman
