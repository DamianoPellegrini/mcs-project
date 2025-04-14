#include <iostream>
#include <functional>
#include <vector>
#include <cstdlib>

#if defined(_WIN32) || defined(_WIN64)
    #define WINDOWS
    #include <windows.h>
    #include <psapi.h>
#else
    #define POSIX
    #include <unistd.h>
    #include <sys/wait.h>
    #include <fstream>
    #include <string>
#endif

size_t measurePeakMemory(std::function<void()> func);
