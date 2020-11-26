# Template Haskell Project
This is a template haskell project to quickly get started using nix.

## Files Layout

- The app:
  - `app/` contains the main file that will generate the binary.
  - `src/` contains the library used by `app/`.
  - `test/` contains the tests testing the library in `src/`.
- Build the app:
  - `package.yaml` is an [`hpack`](https://github.com/sol/hpack) file that generates a cabal file.
  - `stack.yaml`is used by stack to manage the whole project, see [here](https://docs.haskellstack.org/en/stable/stack_yaml_vs_cabal_package_file/).
  - `Makefile` contains all the targets to build the project.
  - `modd.conf` is the config file for [`modd`](https://github.com/cortesi/modd).
- Editor files:
  - `hie.yaml` is the config file for [`ghcide`](https://github.com/haskell/ghcide/).
- Nix files:
  - `default.nix` used when running `nix-build`.
  - `shell.nix` used when running `nix-shell`.
  - `release.nix` is imported by `default.nix` and `shell.nix`.

`nix-shell` includes [`ghcide`](https://github.com/haskell/ghcide/),
an LSP server

```bash
$ nix-shell --pure
[nix-shell] $ ghcide
ghcide version: 0.3.0 (GHC: 8.6) (PATH: /nix/store/i0xbrrhzz5bavwmij7a4rix6fzyh4jhm-ghcide-0.3.0/bin/ghcide)
Ghcide setup tester in /home/timi/projects/hs-template-nix.
Report bugs at https://github.com/digital-asset/ghcide/issues

Step 1/4: Finding files to test in /home/timi/projects/hs-template-nix
Found 4 files

Step 2/4: Looking for hie.yaml files that control setup
Found 1 cradle

Step 3/4: Initializing the IDE
[DEBUG] Warning: Client does not support watched files. Falling back to OS polling

Step 4/4: Type checking the files

[...]

[INFO] finish: User TypeCheck (took 0.06s)

Completed (4 files worked, 0 files failed
```

[`brittany`](https://github.com/lspitzner/brittany), a
code formatter:
```bash
[nix-shell] $ brittany --check-mode */*.hs; echo $?
0
```

and [`hlint`](https://github.com/ndmitchell/hlint), a
code improvement suggester:
```bash
[nix-shell] $ hlint **/*.hs
No hints
```

## Build with nix

```bash
$ nix-build --pure
$ ./result/bin/hs-template-nix-exe
Hello World
```

This runs the tests too. Running this will always recompile
everything, you probably want to use the next section instead.

## Build incrementally

```bash
$ nix-shell --pure --run 'stack build'
$ nix-shell --pure --run 'stack run
Hello World
```

Or, using the makefile:
```bash
$ make build
$ make run
Hello World
```

## Local hoogle server

```bash
$ nix-shell --pure --run 'stack build --haddock --haddock-deps'
$ nix-shell --pure --run 'stack hoogle -- generate --quiet --local'
$ nix-shell --pure --run 'stack hoogle -- server --local --port=65000 --no-security-headers'
```

Or, using the makefile:
```bash
$ make hoogle-build hoogle-generate hoogle-serve
Server starting on port 65000 and host/IP Host "127.0.0.1"
```

Then go to http://localhost:65000/?scope=package%3Ahs-template-nix to
see the documentation of this project. You will see the documentation
for the `Utils` package:

![](assets/utils-doc.png?raw=true)

## Watch files

```bash
$ modd
```

This starts a hoogle server with `make hoogle-serve` as well as runs
in parallel `make hoogle-build hoogle-generate` and `make test`
anytime a file has changed. See [modd.conf](modd.conf).

## Cachix

Cachix integration is provided by the `ibizaman` binary cache:

```bash
cachix use ibizaman
```

Or, with the Makefile:
```bash
make cachix-enable
```

To push to it, run:

```bash
$ nix-build | cachix push ibizaman
$ nix-build shell.nix | cachix push ibizaman
```

Or, with the Makefile:
```bash
make cachix-push
```

## Github Action

A Github Action builds, tests and uploads the binary of the project as
an artifact. Thanks to cachix, this is pretty quick, under 2 minutes.

To download it, follow these steps:
1. Go to the [latest github action run](https://github.com/ibizaman/hs-template-nix/actions).
2. Download the artifact.
3. Unzip it with `unzip hs-template-nix.zip`
4. set the executable permission bit with `chmod a+x hs-template-nix`
5. run it with `./hs-template-nix-exe` and you will see printed `"Hello World"`.

## Editor integration

This is mostly about integrating your editor with the `ghcide`,
`brittany` and `hlint` executables found inside the `nix-shell`.

About `ghcide`, the [hie.nix](hie.nix) file helps it find the files in
the `app/`, `src/` and `test/` folders.

### Emacs

I saw recommended to run your editor directly in nix-shell so it can
access all needed binaries but I don't really like that. Also, I run
an emacs daemon so there's no way this can scale.

Anyway, here is a working config that gracefully loads binary from
inside nix-shell whenever the project is using nix.

```elisp
(setq-default tab-width 4)
(defun my/disable-tabs ()
  "Disable tabs and set them to 4 spaces."
  (setq-default tab-width 4)
  (setq tab-width 4)
  (setq indent-tabs-mode nil))
; Tabs are used to format buffer with `lsp-format-buffer'.
(add-hook 'haskell-mode-hook 'my/disable-tabs)

(defun my/lsp-format-buffer-silent ()
  "Silence errors from `lsp-format-buffer'."
  (ignore-errors (lsp-format-buffer)))

(use-package lsp-mode
  :straight t
  :commands lsp
  :hook ((sh-mode . lsp-deferred)
		 (javascript-mode . lsp-deferred)
		 (html-mode . lsp-deferred)
		 (before-save . my/lsp-format-buffer-silent))
  :config
  (setq lsp-signature-auto-activate t)
  (lsp-lens-mode t))

(use-package lsp-ui
  :straight t
  :hook (lsp-mode-hook . lsp-ui-mode)
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-flycheck-enable t
		lsp-ui-flycheck-live-reporting nil))

(use-package company-lsp
  :straight t
  :commands company-lsp
  :config
  (push 'company-lsp company-backends))

(use-package nix-sandbox
  :straight t)

(use-package haskell-mode
  :straight t
  :after nix-sandbox
  :init
  (defun my/haskell-set-stylish ()
	(if-let* ((sandbox (nix-current-sandbox))
			  (fullcmd (nix-shell-command sandbox "brittany"))
			  (path (car fullcmd))
			  (args (cdr fullcmd)))
	  (setq-local haskell-mode-stylish-haskell-path path
				  haskell-mode-stylish-haskell-args args)))
  (defun my/haskell-set-hoogle ()
	(if-let* ((sandbox (nix-current-sandbox)))
		(setq-local haskell-hoogle-command (nix-shell-string sandbox "hoogle"))))
  :hook ((haskell-mode . capitalized-words-mode)
		 (haskell-mode . haskell-decl-scan-mode)
		 (haskell-mode . haskell-indent-mode)
		 (haskell-mode . haskell-indentation-mode)
		 (haskell-mode . my/haskell-set-stylish)
		 (haskell-mode . my/haskell-set-hoogle)
		 (haskell-mode . lsp-deferred)
		 (haskell-mode . haskell-auto-insert-module-template))
  :config
  (defun my/haskell-hoogle--server-command (port)
	(if-let* ((hooglecmd `("hoogle" "serve" "--local" "-p" ,(number-to-string port)))
			  (sandbox (nix-current-sandbox)))
		(apply 'nix-shell-command sandbox hooglecmd)
	  hooglecmd))
  (setq haskell-hoogle-server-command 'my/haskell-hoogle--server-command
		haskell-stylish-on-save t))

(use-package lsp-haskell
  :straight t
  :after nix-sandbox
  :init
  (setq lsp-prefer-flymake nil)
  (require 'lsp-haskell)
  :config
  ;; from https://github.com/travisbhartwell/nix-emacs#haskell-mode
  (defun my/nix--lsp-haskell-wrapper (args)
	(if-let ((sandbox (nix-current-sandbox)))
		(apply 'nix-shell-command sandbox args)
	  args))
  (setq lsp-haskell-process-path-hie "ghcide"
		lsp-haskell-process-args-hie '()
		lsp-haskell-process-wrapper-function 'my/nix--lsp-haskell-wrapper))

(use-package nix-mode
  :straight t
  :mode "\\.nix\\'"
  :init
  (require 'nix-build))
```
