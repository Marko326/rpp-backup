JohtoOlivinePokecenter1FTextPointers:
	dw JohtoOlivinePublicNoText
	dw JohtoOlivinePublicNoText
	dw JohtoOlivinePublicNoText
	dw JohtoOlivinePublicNoText

; Defensive fallback only. The passive-NPC guard intercepts A before this text.
JohtoOlivinePublicNoText:
	text " "
	done
	db "@"
