public enum EvalError: Error, Equatable {
    case usage(String)
    case download(String)
    case audio(String)
    case fixtures(String)
    case engine(String)
}
