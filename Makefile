PATSCC=$(PATSHOME)/bin/patscc
PATSOPT=$(PATSHOME)/bin/patsopt

PATSCCFLAGS=-DATS_MEMALLOC_LIBC -D_GNU_SOURCE
LDFLAGS=-L$(PATSHOME)/ccomp/atslib/lib -latslib

dungeon: dungeon.sats dungeon.dats
	$(PATSCC) $(PATSCCFLAGS) -o $@ $^ $(LDFLAGS)

#dungeon_dats.o: dungeon.dats
#	$(PATSCC) $(PATSCCFLAGS) -c $<
#
#dungeon_sats.o: dungeon.sats
#	$(PATSCC) $(PATSCCFLAGS) -c $<

%_sats.o: %.sats
	$(PATSCC) $(PATSCCFLAGS) -c $<

%_dats.o: %.dats
	$(PATSCC) $(PATSCCFLAGS) -c $<

clean:
	rm -f dungeon *~ *_?ats.o *_?ats.c

.PHONY: clean
