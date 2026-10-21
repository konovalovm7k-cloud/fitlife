import '../data/repositories/local_fitlife_repository.dart';
import 'state/fitlife_controller.dart';

export '../data/repositories/local_fitlife_repository.dart'
    show PreferencesLoader;

FitLifeController createFitLifeController({
  PreferencesLoader? preferencesLoader,
}) => FitLifeController(
  repository: LocalFitLifeRepository(preferencesLoader: preferencesLoader),
);
