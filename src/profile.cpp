#include "profile.hpp"

size_t measurePeakMemory(std::function<void()> func) {
  #ifdef POSIX
      int pipefd[2];
      pipe(pipefd);
      pid_t pid = fork();
  
      if (pid == 0) {
          close(pipefd[0]);
          func();
          write(pipefd[1], "x", 1);
          close(pipefd[1]);
          _exit(0);
      } else {
          close(pipefd[1]);
          char buf;
          while (read(pipefd[0], &buf, 1) > 0);
          close(pipefd[0]);
  
          waitpid(pid, nullptr, 0);
  
          // Leggi /proc/[pid]/status per VmHWM
          std::string path = "/proc/" + std::to_string(pid) + "/status";
          std::ifstream status(path);
          std::string line;
          size_t hwm = 0;
          while (std::getline(status, line)) {
              if (line.substr(0, 6) == "VmHWM:") {
                  std::sscanf(line.c_str(), "VmHWM: %lu", &hwm);
                  break;
              }
          }
          return hwm; // In KB
      }
  
  #elif defined(WINDOWS)
      // Creiamo un eseguibile temporaneo con la funzione da eseguire.
      // Per semplicità, qui simuliamo la misurazione nello stesso processo.
      // In alternativa, puoi salvare `func()` in un `.exe` separato.
  
      // Simulazione diretta per Windows
      PROCESS_MEMORY_COUNTERS memInfoBefore = {}, memInfoAfter = {};
      GetProcessMemoryInfo(GetCurrentProcess(), &memInfoBefore, sizeof(memInfoBefore));
  
      func(); // Esegui la funzione
  
      GetProcessMemoryInfo(GetCurrentProcess(), &memInfoAfter, sizeof(memInfoAfter));
      SIZE_T peak = memInfoAfter.PeakWorkingSetSize; // In bytes
      return static_cast<size_t>(peak / 1024); // In KB
  #else
      #error "Unsupported platform"
  #endif
  }
  