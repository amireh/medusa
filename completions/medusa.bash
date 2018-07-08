_medusa() {
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(medusa commands)" -- "${COMP_WORDS[COMP_CWORD]}") )
  else
    COMPREPLY=()
  fi
}

complete -F _medusa -o bashdefault -o default medusa
