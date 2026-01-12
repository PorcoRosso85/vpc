# 指示書: `repos/flakes` に CUE 用 flake output を追加する（impl者向け）

## 合意（前提）

- 本タスクは **CUE を `nix flake check` の入力として使える状態**を整えるための「共通flake（`repos/flakes`）」整備である。
- `spec-repo` から本来 input する想定のCUE契約は、当面 **consumer側で `manifest.cue` を置く代替**でよい（契約正本は別途）。
- `cue` バージョンは **`spec-repo` と一致**させる（現在は v0.15.1 で固定）。

## 現状確認（必須）

### 1) `spec-repo` 側の CUE 実装を確認

- `repos/spec-repo/flake.nix` に `cue-v15` の定義がある。
  - `pkgs.buildGoModule` で `cue-lang/cue` を `version = "0.15.1"` に固定し、`hash`/`vendorHash` も固定している。
  - この「バージョン + ハッシュ」のセットが consumer でも再現できることが重要。

確認コマンド（例）:

- `nix eval --raw /home/nixos/repos/spec-repo#packages.x86_64-linux.cue-v15.name`（※ packages に露出していれば）
- `nix build /home/nixos/repos/spec-repo#packages.x86_64-linux.cue-v15 -L`

※ `spec-repo` の `cue-v15` を「そのまま input として再利用」する案は、依存関係が太くなる・循環しやすいので基本は避け、`repos/flakes` に同等の derivation を定義する。

### 2) `repos/flakes` 側の flake 構造を確認

- `repos/flakes/flake.nix` は `flake-parts` ベースで、現状 `parts/devshell.nix` と `parts/devshell-check.nix` のみを import している。
- `packages` を公開していない（devshell中心）。

確認コマンド（例）:

- `nix flake show /home/nixos/repos/flakes`

## 実装方針（DRY/KISS/YAGNI/SOLID）

- **KISS**: `repos/flakes` に「`cue` をビルドして expose する」だけを追加する（まずは1パッケージ + 1チェック）。
- **DRY**: `spec-repo` で確定した `cue-v15` の pin（version/hash/vendorHash）を流用し、各consumer repoが個別に `buildGoModule` を持たないようにする。
- **YAGNI**: overlay/複雑な module 設計は後回し。まずは `packages.<system>.cue-v15` と `checks.<system>.cue-smoke` を出す。
- **SOLID**: `parts/cue.nix` の1ファイルに閉じ、他のparts（devshell）とは独立させる。

## 期待する最終アウトプット（`repos/flakes`）

### 1) `packages.<system>.cue-v15` を追加

- `cue` バージョン `0.15.1` の固定ビルドを提供する。
- 対象 `systems` は `repos/flakes/flake.nix` の `systems` に従う（現状は `x86_64-linux` / `aarch64-linux`）。

### 2) `checks.<system>.cue-smoke` を追加

- `cue` バイナリの最低限の動作確認（例: `cue version` 実行）
- 可能なら `cue fmt` / `cue vet` を最小fixtureに当てる（fixtureは flakes repo側に置くなら最小で）

### 3) （任意）`devShells.cue` を追加

- consumer repo の `flake check` が失敗した時のトリアージ用に、`cue` 単体の devshell があると便利。

## 実装手順（推奨）

1. `repos/flakes/parts/cue.nix` を新規追加
   - `perSystem = { pkgs, ... }: { packages.cue-v15 = ...; checks.cue-smoke = ...; }` の形式
   - `cue-v15` derivation は `spec-repo/flake.nix` の `cue-v15` と同等にする

2. `repos/flakes/flake.nix` に `./parts/cue.nix` を `imports` に追加
   - 既存 devshell parts を壊さない

3. `nix flake check /home/nixos/repos/flakes -L` が通ることを確認

## consumer 側（例: vpc repo）での使い方（参考）

- `inputs.flakes.url = "path:/home/nixos/repos/flakes"`（ローカル参照例。実運用はgit URLへ）
- `inputs.flakes.packages.${system}.cue-v15` を `nativeBuildInputs` に入れて `cue vet` を `checks` から呼ぶ

このとき consumer repo には `manifest.cue` を置き、正常集合（allowed endpoints / required bindings 等）を `cue vet` で検証する。

---

## DoD（この指示書の完了条件）

- `repos/flakes` が `packages.<system>.cue-v15` を公開している
- `repos/flakes` の `nix flake check` で `checks.<system>.cue-smoke` が実行される
- consumer repo が `cue` を自前ビルドせずに `flake check` で `cue vet` を回せる見込みが立つ
