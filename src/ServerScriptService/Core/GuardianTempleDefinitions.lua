local Definitions={
    Arena=table.freeze({SizeX=90,SizeZ=62,CenterZ=-5}),
    Spawn=table.freeze({X=0,Y=1,Z=23,LookX=0,LookY=8,LookZ=-18}),
    Judges=table.freeze({
        RIVET=table.freeze({X=-23,Y=18.5,Z=-27,Height=22,YawDegrees=0}),
        PIP=table.freeze({X=0,Y=22.5,Z=-32,Height=26,YawDegrees=180}),
        MOSS=table.freeze({X=23,Y=18.5,Z=-27,Height=22,YawDegrees=0}),
    }),
    Collectibles=table.freeze({
        BLIP=table.freeze({X=-34,Y=2,Z=17}),
        ZAPP=table.freeze({X=34,Y=2,Z=17}),
        CHOMP=table.freeze({X=0,Y=2,Z=-5}),
    }),
    Sounds=table.freeze({
        TurnStart="6026984224",
        TenSecondWarning="6026984224",
        ScoreTick="",
        VerdictSting="",
        MatchWin="",
    }),
}
return table.freeze(Definitions)
