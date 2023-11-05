#!/bin/sh

set -e

if sh "set -o pipefail" > /dev/null 2>&1; then
  # shellcheck disable=SC3040
  set -o pipefail
fi

sanitize() {
  printf "%s\n" "${1}" \
    | sed 's/&/\&amp;/g' \
    | sed 's/</\&lt;/g' \
    | sed 's/>/\&gt;/g'
}

arg2name() {
  sanitize "${1}" \
    | sed 's/^-*\([^=^\[]*\).*/\1/g'
}

arg2placeholder() {
  sanitize "$(
    printf "%s\n" "${1}" \
      | sed 's/[^=^\[]*\(\[\?\)=\(.*\)\]\?/\1\2/g'
  )"
}

if [ "$#" -lt 1 ]; then
  cat <<EOF
<!DOCTYPE html>
<html>
<head>
<title>Commands</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
:root {
  /*
  --main-fg: limegreen;
  --main-bg: black;
  */
  --main-fg: black;
  --main-bg: white;
}

html {
  width: 100vw;
  max-width: 100%;
  padding: 0;
  margin: 0;
  background: var(--main-bg);
  color: var(--main-fg);
  font-family: monospace, monospace;
}

body {
  padding: 0;
  margin: 3em auto;
  max-width: 100ch;
}

.vbox {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  justify-content: flex-start;
  align-items: center;
}
</style>
<script>
if (!window.location.pathname.endsWith("/")) {
  window.location.replace(window.location + "/");
}
</script>
</head>
<body>
<div class="vbox">
$(
  printf "%s\n" "${PATH}" \
    | tr ':' '\n' \
    | sed 's:^~:'"$(realpath ~)"':' \
    | xargs -P 8 -I {} find {} -maxdepth 1 -type f -executable \
    | xargs -P 8 -I {} basename "{}" \
    | sort \
    | uniq \
    | sed 's,\(.*\),<a href="?\1">\1</a>,g'
)
</div>
</body>
</html>
EOF
  exit
fi

COMMAND="${1}"
shift;

if "${COMMAND}" --help > /dev/null 2>&1; then
  HELP="$("${COMMAND}" --help 2>&1)"
elif "${COMMAND}" -h > /dev/null 2>&1; then
  HELP="$("${COMMAND}" -h 2>&1)"
elif "${COMMAND}" > /dev/null 2>&1; then
  HELP="$("${COMMAND}" 2>&1)"
else
  printf "%s\n" "Command $(sanitize "${COMMAND}") not found."
  exit
fi

# Enable actually running the commands. UNSAFE!
# mkdir --parents links
# ln \
#   --force \
#   --symbolic \
#   "$(command -v "${COMMAND}")" \
#   "links/$(basename "${COMMAND}")"

ARGS_WITH_DESCRIPTIONS="$(
  printf "%s\n" "${HELP}" \
    | tr '\n' '\r' \
    | sed 's/\r[[:space:]]*-/\n-/g' \
    | sed 's/\r\r/\n/g' \
    | tr '\r' '   ' \
    | sed 's/,  *-/,-/g' \
    | sed 's/\(--\?[^ ][^ ]*\) \([^ ][^ ]*\)   */\1=\2  /g' \
    | grep '^[[:space:]]*-' \
    | grep -v '^\(- *\)\(- *\)*$' \
    | sed 's/[[:space:]][[:space:]]*/ /g' \
    | sed 's/^[[:space:]]*//g' \
    | sed 's/$/ /g' \
    | sed ':label; s/<\([^>]*\) \([^>]*\)>/<\1-\2>/g; t label' \
    | sed 's/\(--\?[^ ^=][^ ^=]*\)[ =]<\([^>][^>]*\)>/\1=\2/g'
)"

ARGS="$(
  printf "%s\n" "${ARGS_WITH_DESCRIPTIONS}" \
    | cut -d ' ' -f 1 \
    | sed 's/.*,\(-.*\)/\1/g'
)"

DESCRIPTIONS="$(
  printf "%s\n" "${ARGS_WITH_DESCRIPTIONS}" \
    | cut -d ' ' -f 2-
)"

cat <<EOF
<!DOCTYPE html>
<html>
<head>
<title>$(sanitize "${COMMAND}") GUI</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<style>
:root {
  --main-fg: black;
  --main-bg: white;
}

html {
  width: 100vw;
  max-width: 100%;
  padding: 0;
  margin: 0;
  background: var(--main-bg);
  color: var(--main-fg);
  font-family: monospace, monospace;
}

body {
  padding: 0 5ch;
  margin: 3em auto;
  max-width: 100ch;
}

hr {
  color: none;
  background: none;
  border: none;
  border-top: 2px solid var(--main-fg);
  margin: 2em 0;
}

pre,
code,
hr,
label {
  width: 100%;
}

summary {
  cursor: pointer;
}

label {
  /*
    Strange tricks so wrapped text is indented and doesn't end up underneath
    the checkboxes.
  */
  padding-left: 4ch;
  text-indent: -4ch;
}

input[type="checkbox"],
input[type="text"] {
  margin-right: 2ch;
}

button {
  margin: 0 1ch;
}

.sticky {
  position: sticky;
  top: 0;
  background: var(--main-bg);
  padding: 1em 0;
  margin: -1em -4ch;
  margin-bottom: 0;
  display: flex;
  flex-direction: row;
  flex-wrap: nowrap;
  justify-content: space-between;
  align-items: center;
}

.sticky > p {
  flex-grow: 1;
}

.short {
  max-height: 20em;
  overflow-y: auto;
}

.vbox {
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  justify-content: flex-start;
  align-items: center;
}

.non-flag {
  width: 100%;
  margin: 0.5em 0;
}
</style>
<script>
function flag(s) {
  if (s[0] === "-") {
    return s;
  }
  return "-" + (s.length > 1 ? "-" : "") + s;
}

function update() {
  const flags = Array.from(document.querySelectorAll("label"))
    .forEach(l => {
      const checkbox = l.querySelector("input[type='checkbox']");
      const textInput = l.querySelector("input[type='text']");
      if (textInput) {
        textInput.disabled = !checkbox.checked;
      }
    });

  buildCommand();
}

function buildCommand() {
  const command = "$(sanitize "${COMMAND}")";
  const flags = Array.from(document.querySelectorAll("label"))
    .filter(l => {
      const checkbox = l.querySelector("input[type='checkbox']");
      return checkbox.checked;
    })
    .map(l => {
      const textInput = l.querySelector("input[type='text']");
      if (textInput && textInput.value) {
        return [flag(textInput.name), "'" + textInput.value + "'"];
      } else if (textInput) {
        return flag(textInput.name);
      } else {
        const checkbox = l.querySelector("input[type='checkbox']");
        return flag(checkbox.name);
      }
    })
    .flat()
    .join(" ");

  const arguments = Array.from(document.querySelectorAll(".non-flag"))
    .map(i => "'" + i.value + "'")
    .join(" ");

  const p = document.querySelector(".sticky > p");
  p.innerText = command + " " + flags + " " + arguments;
}

function submitCommand() {
  const flags = Array.from(document.querySelectorAll("label"))
    .forEach(l => {
      const checkbox = l.querySelector("input[type='checkbox']");
      const textInput = l.querySelector("input[type='text']");
      if (checkbox.checked && textInput && textInput.value === "") {
        textInput.name = flag(textInput.name);
      } else if (checkbox.checked && textInput && textInput.value !== "") {
        textInput.name = textInput.name.replace(/^--*/, '');
      }
    });

  Array.from(document.querySelectorAll(".non-flag"))
    .forEach(i => {
      i.name = i.value;
      i.value = "";
    });

  document.querySelector("form").submit();
}

function addArgument() {
  const form = document.querySelector("form");
  const input = document.createElement("input");
  input.className = "non-flag";
  input.type = "text";
  input.oninput = update;

  const formInputs = form.querySelectorAll(".non-flag");
  if (formInputs.length == 0) {
    form.prepend(input);
  } else {
    formInputs[formInputs.length - 1]
      .insertAdjacentElement("afterend", input);
  }
}
</script>
</head>
<body>
<div class="sticky">
<p>$(sanitize "${COMMAND}")</p>
<button onclick="addArgument()">Add argument</button>
<button onclick="submitCommand()">Run Command</button>
</div>
<form action="links/$(sanitize "${COMMAND}")" method="GET" class="vbox">
EOF

ARG_NUM=1
for ARG in ${ARGS}; do
  DESCRIPTION="$(
    printf "%s\n" "${DESCRIPTIONS}" | tail "+${ARG_NUM}" | head -n 1
  )"

  # Must use printf instead of echo in case one of the args is -e or -n
  if printf "%s\n" "${ARG}" | grep "=" > /dev/null 2>&1; then
    printf "%s\n" "<label title='$(
        sanitize "${ARG}"
      )'><input type='checkbox' onchange='update()'" \
      "><input type='text' oninput='update()' placeholder='$(
        arg2placeholder "${ARG}"
      )' name='$(
        arg2name "${ARG}"
      )' disabled>$(
          if ! (
            printf "%s\n" "${DESCRIPTION}" \
              | grep "^[[:space:]]*$" \
              > /dev/null
          ); then
            sanitize "${DESCRIPTION}"
          else
            sanitize "${ARG}"
          fi
      )</label>"
  else
    printf "%s\n" "<label title='$(
        sanitize "${ARG}"
      )'><input type='checkbox' value='' name='$(
        sanitize "${ARG}"
      )' onchange='update()'>$(
        if ! (
          printf "%s\n" "${DESCRIPTION}" \
            | grep "^[[:space:]]*$" \
            > /dev/null
        ); then
          sanitize "${DESCRIPTION}"
        else
          sanitize "${ARG}"
        fi
      )</label>"
  fi

  ARG_NUM=$(( ARG_NUM + 1 ))
done

cat <<EOF
</form>
<hr>
<pre class="short"><code>$(
  sanitize "${HELP}"
)</code></pre>
</body>
</html>
EOF

