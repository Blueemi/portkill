import { execFile } from "node:child_process";
import { promisify } from "node:util";

import type { PortProcess } from "./types";

const execFileAsync = promisify(execFile);

export class PortScannerError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PortScannerError";
  }
}

export async function scanPorts(): Promise<PortProcess[]> {
  try {
    const { stdout } = await execFileAsync("/usr/sbin/lsof", ["-nP", "-iTCP", "-sTCP:LISTEN", "-F", "pcPn"], {
      maxBuffer: 10 * 1024 * 1024,
    });
    return parseLsofOutput(stdout);
  } catch (error) {
    const err = error as NodeJS.ErrnoException & { stdout?: string; stderr?: string };
    const output = err.stdout?.trim() ?? "";
    if (output.length > 0) {
      return parseLsofOutput(output);
    }

    const stderr = err.stderr?.trim();
    const message = stderr && stderr.length > 0 ? stderr : err.message || "lsof failed";
    throw new PortScannerError(message);
  }
}

function parseLsofOutput(output: string): PortProcess[] {
  let currentPID: number | undefined;
  let currentCommand = "Unknown";
  let currentProtocol = "TCP";
  const rows: PortProcess[] = [];
  const seen = new Set<string>();

  for (const rawLine of output.split("\n")) {
    if (rawLine.length === 0) {
      continue;
    }

    const marker = rawLine[0];
    const value = rawLine.slice(1);

    switch (marker) {
      case "p":
        currentPID = Number.parseInt(value, 10);
        currentCommand = "Unknown";
        currentProtocol = "TCP";
        break;
      case "c":
        currentCommand = value.length > 0 ? value : "Unknown";
        break;
      case "P":
        currentProtocol = value.length > 0 ? value : "TCP";
        break;
      case "n": {
        if (currentPID === undefined || Number.isNaN(currentPID)) {
          break;
        }

        const port = extractPort(value);
        if (port === undefined) {
          break;
        }

        const uniqueKey = `${currentPID}-${port}-${value}`;
        if (seen.has(uniqueKey)) {
          break;
        }
        seen.add(uniqueKey);

        rows.push({
          id: uniqueKey,
          port,
          processName: currentCommand,
          pid: currentPID,
          endpoint: value,
          protocolName: currentProtocol,
        });
        break;
      }
      default:
        break;
    }
  }

  return rows.sort((left, right) => {
    if (left.port !== right.port) {
      return left.port - right.port;
    }

    const nameCompare = left.processName.localeCompare(right.processName, undefined, { sensitivity: "base" });
    if (nameCompare !== 0) {
      return nameCompare;
    }

    return left.pid - right.pid;
  });
}

function extractPort(endpoint: string): number | undefined {
  const localEndpoint = endpoint.split("->")[0] ?? endpoint;
  const colonIndex = localEndpoint.lastIndexOf(":");
  if (colonIndex === -1) {
    return undefined;
  }

  const afterColon = localEndpoint.slice(colonIndex + 1);
  let portText = "";
  for (const character of afterColon) {
    if (character >= "0" && character <= "9") {
      portText += character;
    } else {
      break;
    }
  }

  if (portText.length === 0) {
    return undefined;
  }

  const port = Number.parseInt(portText, 10);
  return Number.isNaN(port) ? undefined : port;
}
