
TARGETS = brudpr brudps
CFLAGS = -O0 -g
#CFLAGS = -O3
CC = gcc

all: $(TARGETS)

brudpr: brudpr.o
	$(CC) $< -o $@

brudps: brudps.o
	$(CC) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f *.o $(TARGETS)

