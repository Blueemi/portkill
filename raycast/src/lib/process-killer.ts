import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

export class ProcessKillerError extends Error {
  readonly pid: number;

  constructor(pid: number, message: string) {
    super(`Could not kill PID ${pid}: ${message}`);
    this.name = "ProcessKillerError";
    this.pid = pid;
  }
}

export async function killProcess(pid: number): Promise<void> {
  if (pid <= 0) {
    return;
  }

  await sendSignal(pid, "TERM");
  await sleep(450);

  if (await processExists(pid)) {
    await sendSignal(pid, "KILL");
  }
}

export async function killProcesses(pids: Iterable<number>): Promise<void> {
  const sorted = [...new Set(pids)].filter((pid) => pid > 0).sort((a, b) => a - b);
  for (const pid of sorted) {
    await killProcess(pid);
  }
}

async function sendSignal(pid: number, signal: "TERM" | "KILL"): Promise<void> {
  try {
    await execFileAsync("/bin/kill", [`-${signal}`, String(pid)]);
  } catch (error) {
    const err = error as NodeJS.ErrnoException;
    if (err.code === "ESRCH") {
      return;
    }
    throw new ProcessKillerError(pid, err.message || `kill -${signal} failed`);
  }
}

async function processExists(pid: number): Promise<boolean> {
  try {
    await execFileAsync("/bin/kill", ["-0", String(pid)]);
    return true;
  } catch {
    return false;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
