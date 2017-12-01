\version "2.18.2"

Melody = \relative c' {
  \clef "treble"
  \key g \major
  \numericTimeSignature \time 4/4
  | b4 e8( fis) g4 g
  | fis2 e4 r
  | d4 g8( a) b4 b
  | a2. r4
  | a4 a8 b c4 d8 c
  | b4 a g2
  | fis4. g8 a4 g8 fis
  | e1
}

Chords = \chordmode {
  | e1:m | b2:7 e:m
  | g1 | a:m
  | a2:m7 d:7 | g2 e:m
  | a2:m b:7 | e1:m
}

LyricsOne = \lyricmode {
  Gör -- kem -- li A -- do -- nay,
  Kral -- lar -- ın Kra -- lı,
  ka -- nat -- la -- rın -- da şi -- fa o -- lan
  Doğ -- ru -- luk Gü -- ne -- şi.
}

\score {
  <<
    \context ChordNames = "Chords" \Chords
    \new Staff {
      \context Staff
      <<
        \context Voice = "Melody" \Melody
        \new Lyrics \lyricsto "Melody" \LyricsOne
      >>
    }
  >>
}
