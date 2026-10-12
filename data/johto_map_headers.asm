; REG-5.62.118: Johto's independent local-ID tables, in Bank $40.
; Keep the pointer and bank entries in exactly the same local-ID order.
JohtoMapHeaderPointers::
	dw NewBarkTown_h ; local $00 (legacy NEW_BARK_TOWN = $E7)
JohtoMapHeaderPointersEnd::

JohtoMapHeaderBanks::
	db BANK(NewBarkTown_h)
JohtoMapHeaderBanksEnd::

ASSERT JohtoMapHeaderPointersEnd - JohtoMapHeaderPointers == NUM_JOHTO_MAPS * 2
ASSERT JohtoMapHeaderBanksEnd - JohtoMapHeaderBanks == NUM_JOHTO_MAPS
ASSERT NEW_BARK_TOWN == $E7
