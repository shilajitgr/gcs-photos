/**
 * Structured JSON logger compatible with Google Cloud Logging.
 *
 * Cloud Logging parses JSON lines from stdout/stderr and maps the
 * "severity" field to log levels automatically.
 */

type Severity = "DEBUG" | "INFO" | "WARNING" | "ERROR" | "CRITICAL";

interface LogEntry {
  severity: Severity;
  message: string;
  timestamp: string;
  [key: string]: unknown;
}

function emit(severity: Severity, message: string, fields?: Record<string, unknown>): void {
  const entry: LogEntry = {
    severity,
    message,
    timestamp: new Date().toISOString(),
    ...fields,
  };
  const line = JSON.stringify(entry);
  if (severity === "ERROR" || severity === "CRITICAL") {
    process.stderr.write(line + "\n");
  } else {
    process.stdout.write(line + "\n");
  }
}

export const logger = {
  debug(message: string, fields?: Record<string, unknown>): void {
    emit("DEBUG", message, fields);
  },
  info(message: string, fields?: Record<string, unknown>): void {
    emit("INFO", message, fields);
  },
  warn(message: string, fields?: Record<string, unknown>): void {
    emit("WARNING", message, fields);
  },
  error(message: string, fields?: Record<string, unknown>): void {
    emit("ERROR", message, fields);
  },
  critical(message: string, fields?: Record<string, unknown>): void {
    emit("CRITICAL", message, fields);
  },
};
