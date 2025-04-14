CXX = g++
CXXFLAGS = -Wall -std=c++20 -march=native
LDFLAGS = -framework Accelerate -L$(shell brew --prefix lapack)/lib -llapacke

SRC_DIR = src
LIB_DIR = lib
OBJ_DIR = target/obj
BIN_DIR = target
TARGET = $(BIN_DIR)/main
SUITESPARSE_BUILD = lib/suitesparse/lib/libcholmod.a

# Trova tutte le sottodirectory in lib/ per includerle come -I
INCLUDES := $(LIB_DIR)/eigen $(LIB_DIR)/fast_matrix_market/include $(LIB_DIR)/suitesparse/include/suitesparse # $(LIB_DIR)/suitesparse/include
INCLUDE_FLAGS := $(addprefix -I, $(INCLUDES))

DEFINES := EIGEN_USE_LAPACKE
DEFINE_FLAGS := $(addprefix -D, $(DEFINES))

CXXFLAGS += $(INCLUDE_FLAGS)
CXXFLAGS += $(DEFINE_FLAGS)
# cholmod requires AMD, COLAMD, CCOLAMD, the BLAS, and LAPACK, linking is done at load time so we force static linking
LDFLAGS += \
	$(LIB_DIR)/suitesparse/lib/libcholmod.a \
	$(LIB_DIR)/suitesparse/lib/libsuitesparseconfig.a \
	$(LIB_DIR)/suitesparse/lib/libamd.a \
  $(LIB_DIR)/suitesparse/lib/libcolamd.a \
  $(LIB_DIR)/suitesparse/lib/libccolamd.a \
  $(LIB_DIR)/suitesparse/lib/libcamd.a
# oppure
# LDFLAGS += -Wl,-rpath,$(LIB_DIR)/suitesparse/lib

# Trova tutti i file .cpp in src/
SRCS := $(wildcard $(SRC_DIR)/*.cpp)
# Converte i path dei file .cpp in file .o sotto target/obj/
OBJS := $(patsubst $(SRC_DIR)/%.cpp, $(OBJ_DIR)/%.o, $(SRCS))

# Regola principale
all: $(TARGET)

# Link finale
$(TARGET): $(OBJS)
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# Regola per compilare ogni .cpp in .o
# La compilazione di suitesparse è messa qui perché altrimenti non trova gli header file
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp $(SUITESPARSE_BUILD)
	@mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(SUITESPARSE_BUILD):
	$(MAKE) -C lib/suitesparse local
	$(MAKE) -C lib/suitesparse install

clean:
	rm -rf $(OBJ_DIR) $(TARGET)
	$(MAKE) -C lib/suitesparse purge

.PHONY: all clean
