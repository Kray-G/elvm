CFLAGS := -m32 -W -Wall -MMD -O -g

ELI := out/eli
8CC := out/8cc
BINS := $(ELI) $(8CC) out/dump_ir

all: test

CSRCS := ir/ir.c ir/table.c ir/dump_ir.c eli.c
COBJS := $(addprefix out/,$(notdir $(CSRCS:.c=.o)))
$(COBJS): out/%.o: ir/%.c
	$(CC) -c $(CFLAGS) $< -o $@

out/dump_ir: out/ir.o out/table.o out/dump_ir.o
	$(CC) $(CFLAGS) -DTEST $^ -o $@

out/eli: out/ir.o out/table.o out/eli.o
	$(CC) $(CFLAGS) $^ -o $@

$(8CC): $(wildcard 8cc/*.c 8cc/*.h)
	$(MAKE) -C 8cc && cp 8cc/8cc $@

# Stage tests

$(shell mkdir -p out)

CTEST_SRCS := $(wildcard test/*.c)
CTEST_STAGED := $(CTEST_SRCS:test/%.c=out/%.c)
$(CTEST_STAGED): out/%.c: test/%.c
	cp $< $@.tmp && mv $@.tmp $@
OUT.c := $(CTEST_SRCS:test/%.c=%.c)

out/8cc.c:
	./merge_8cc.sh > $@.tmp && mv $@.tmp $@
OUT.c += 8cc.c

# Build tests

TEST_INS := $(wildcard test/*.in)

include clear_vars.mk
SRCS := $(OUT.c)
EXT := exe
CMD = $(CC) -Ilibc $2 -o $1
OUT.c.exe := $(SRCS:%=%.$(EXT))
include build.mk

include clear_vars.mk
SRCS := $(OUT.c.exe)
EXT := out
DEPS := $(TEST_INS) runtest.sh
CMD = ./runtest.sh $1 $2
include build.mk

include clear_vars.mk
SRCS := $(OUT.c)
EXT := eir
CMD = $(8CC) -S -Ilibc $2 -o $1
OUT.c.eir := $(SRCS:%=%.$(EXT))
include build.mk

include clear_vars.mk
SRCS := $(OUT.c.eir)
EXT := out
CMD = ./runtest.sh $1 $(ELI) $2
include build.mk

test: $(TEST_RESULTS)

-include */*.d