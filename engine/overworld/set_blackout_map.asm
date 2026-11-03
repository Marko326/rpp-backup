; DEV-334: do not put Johto's shared $fc runtime handle into Kanto's
; wLastBlackoutMap. Move the original Kanto table/body into reusable ROMX.
SetLastBlackoutMap:
    callab SetLastBlackoutMapRegional
    ret
