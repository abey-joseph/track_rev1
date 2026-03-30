.PHONY: get gen gen-watch gen-delete test analyze format format-check clean rebuild run-dev run-prod build-apk-dev build-apk-prod build-ios-dev build-ios-prod

## Install dependencies
get:
	flutter pub get

## Run all code generators once
gen:
	dart run build_runner build --delete-conflicting-outputs

## Run code generators in watch mode
gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

## Delete all generated files and rebuild
gen-delete:
	dart run build_runner clean
	dart run build_runner build --delete-conflicting-outputs

## Run tests with coverage
test:
	flutter test --coverage

## Run tests for a specific feature (usage: make test-feature FEATURE=auth)
test-feature:
	flutter test test/features/$(FEATURE)/

## Static analysis
analyze:
	flutter analyze --fatal-infos

## Format code
format:
	dart format lib/ test/ --line-length 80

## Check format without modifying
format-check:
	dart format lib/ test/ --set-exit-if-changed --line-length 80

## Clean build artifacts
clean:
	flutter clean
	rm -rf .dart_tool/build/

## Full rebuild from scratch
rebuild: clean get gen

## Run app in dev mode
run-dev:
	flutter run --dart-define=ENV=dev

## Run app in prod mode
run-prod:
	flutter run --dart-define=ENV=prod

## Build APK for dev
build-apk-dev:
	flutter build apk --dart-define=ENV=dev

## Build APK for prod
build-apk-prod:
	flutter build apk --dart-define=ENV=prod --release

## Build iOS for dev (no codesign)
build-ios-dev:
	flutter build ios --dart-define=ENV=dev --no-codesign

## Build iOS for prod
build-ios-prod:
	flutter build ios --dart-define=ENV=prod --release
