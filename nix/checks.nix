{
  pkgs,
  cue,
  self,
}:

let
  manifestFile = "${self}/manifest.cue";
in
pkgs.runCommand "vpc-fast" { nativeBuildInputs = [ cue ]; } ''
  mkdir -p "$out"
  report="$out/report.txt"

  failures=0

  run_case() {
    name="$1"
    shift

    {
      echo "## $name"
      echo "cmd: $*"
    } >>"$report"

    "$@" >>"$report" 2>&1
    rc=$?

    if [ "$rc" -ne 0 ]; then
      echo "result: FAIL (rc=$rc)" >>"$report"
      failures=$((failures + 1))
    else
      echo "result: OK" >>"$report"
    fi

    echo "" >>"$report"
    return 0
  }

  read_cue_value() {
    expr="$1"
    ${cue}/bin/cue eval -e "$expr" -c "${manifestFile}" 2>/dev/null | tr -d '"\n'
  }

  run_case "cue.eval.manifest" ${cue}/bin/cue eval -c -e manifest "${manifestFile}" >/dev/null

  required_binding="$(read_cue_value 'manifest.requiredBindings[0]')"
  if [ "$required_binding" != "OPENCODE_SERVICE" ]; then
    {
      echo "## manifest.requiredBindings"
      echo "expected: OPENCODE_SERVICE"
      echo "actual:   $required_binding"
      echo "result: FAIL"
      echo ""
    } >>"$report"
    failures=$((failures + 1))
  else
    {
      echo "## manifest.requiredBindings"
      echo "expected: OPENCODE_SERVICE"
      echo "actual:   $required_binding"
      echo "result: OK"
      echo ""
    } >>"$report"
  fi

  health_method="$(read_cue_value 'manifest.opencode.health.method')"
  health_path="$(read_cue_value 'manifest.opencode.health.path')"

  if [ "$health_method" != "GET" ] || [ "$health_path" != "/health" ]; then
    {
      echo "## manifest.opencode.health"
      echo "expected: GET /health"
      echo "actual:   $health_method $health_path"
      echo "result: FAIL"
      echo ""
    } >>"$report"
    failures=$((failures + 1))
  else
    {
      echo "## manifest.opencode.health"
      echo "expected: GET /health"
      echo "actual:   $health_method $health_path"
      echo "result: OK"
      echo ""
    } >>"$report"
  fi

  doc_method="$(read_cue_value 'manifest.opencode.doc.method')"
  doc_path="$(read_cue_value 'manifest.opencode.doc.path')"

  if [ "$doc_method" != "GET" ] || [ "$doc_path" != "/openapi.json" ]; then
    {
      echo "## manifest.opencode.doc"
      echo "expected: GET /openapi.json"
      echo "actual:   $doc_method $doc_path"
      echo "result: FAIL"
      echo ""
    } >>"$report"
    failures=$((failures + 1))
  else
    {
      echo "## manifest.opencode.doc"
      echo "expected: GET /openapi.json"
      echo "actual:   $doc_method $doc_path"
      echo "result: OK"
      echo ""
    } >>"$report"
  fi

  if [ "$failures" -ne 0 ]; then
    echo "summary: FAIL ($failures case(s) failed)" >>"$report"
    exit 1
  fi

  echo "summary: OK" >>"$report"
  touch "$out/ok"
''
