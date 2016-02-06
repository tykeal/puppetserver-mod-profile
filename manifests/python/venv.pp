# Class profile::python::venv
#
# Used for setting up needed environment if a python virtenv / venv is
# going to be used
class profile::python::venv {
  # Venv's typically need to compile packages
  ensure_packages(['gcc', 'make'])
  include ::python
}
