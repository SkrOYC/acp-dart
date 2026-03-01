{ pkgs, lib, config, inputs, ... }:

{
  # Dart SDK - https://devenv.sh/languages/dart/
  languages.dart.enable = true;

  # Development scripts
  scripts = {
    setup.exec = "dart pub get";
    test.exec = "dart test";
    analyze.exec = "dart analyze";
    build.exec = "dart run build_runner build";
  };

  # Run on `devenv shell` entry
  enterShell = ''
    dart pub get
    echo "Run 'devenv run test' to run tests"
  '';

  # Tests run with `devenv test`
  enterTest = ''
    dart test
  '';
}
