@echo off
echo Running build_runner to generate injector.config.dart...
flutter pub run build_runner build --delete-conflicting-outputs
echo Done!
