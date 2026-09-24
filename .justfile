_default:
  @just --choose

_release level:
  oxr release --execute {{level}}

release-major:
  just _release major

release-minor:
  just _release minor

release-patch:
  just _release patch
