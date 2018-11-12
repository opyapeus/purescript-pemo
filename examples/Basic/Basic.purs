module Basic where

import Prelude

import Data.Foldable (any)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Effect (Effect)
import Nemo (nemoDev)
import Nemo.Class.Game (class Game)
import Nemo.Constants (scene)
import Nemo.Data.Color (Color(..))
import Nemo.Data.Emoji as E
import Nemo.Data.Tone (Tone(..))
import Nemo.Draw (cls, emap, emo, emo')
import Nemo.Sound (play)
import Nemo.Types (Size, X, Y)
import Nemo.Utils (isMapCollide, isMonitorCollide, mkAsset, defaultDebugConfig)
import Nemo.Parse (RawMap(..), RawSound(..))

emoSize :: Size
emoSize = 64

mapSize :: Size
mapSize = 64

gravity :: Int
gravity = 2

data State = State
  { x :: Int
  , y :: Int
  , dy :: Int
  , isJump :: Boolean
  , appear :: Appear
  , frame :: Int
  }
derive instance genericState :: Generic State _
instance showState :: Show State where
  show = genericShow

data Appear = LeftWalk | RightWalk | LeftRun | RightRun
derive instance genericAppear :: Generic Appear _
instance showAppear :: Show Appear where
  show = genericShow

instance gameState :: Game State where
  update asset input (State state) = do
    -- next x
    let nx = case input.isLeft, input.isRight of
          true, false -> state.x - 10
          false, true-> state.x + 10
          _, _ -> state.x

    -- next y, dy
    let canJump = isCollide state.x (state.y - gravity)
        isJump = canJump && input.isUpCat
        ddy = if isJump then 40 else 0
        ndy = state.dy - gravity + ddy
        ny = state.y + ndy

    -- final x, y, dy
    -- FIXME: rough adjust
    let isCollX = isCollide nx state.y
        isCollY = isCollide state.x ny
        nnx = if isCollX then state.x else nx
        nny = if isCollY then state.y else ny
        nndy = if isCollY then gravity else ndy

    -- next appearance
    let isAppearRun = mod state.frame 8 < 4
        appear = case input.isLeft, input.isRight of
          true, false -> if isAppearRun then LeftRun else LeftWalk 
          false, true -> if isAppearRun then RightRun else RightWalk
          _, _ -> case state.appear of
                LeftRun -> LeftWalk
                RightRun -> RightWalk
                _ -> state.appear

    -- next state  
    pure <<< State $ state
      { x = nnx
      , y = nny
      , dy = nndy
      , isJump = isJump
      , appear = appear
      , frame = state.frame + 1
      }
    where
      isCollide :: X -> Y -> Boolean
      isCollide x y =
        any
          (\f -> f emoSize x y)
          [ isMapCollide asset 0 mapSize walls
          , isMonitorCollide
          ]

  draw (State state) =
    [ cls Silver
    , emap 0 emoSize 0 0
    , emoF emoSize state.x state.y
    ]
    where
      emoF = case state.appear of
        LeftWalk -> emo E.personWalking
        RightWalk -> emo' E.personWalking
        LeftRun -> emo E.personRunning
        RightRun -> emo' E.personRunning

  sound (State state) =
    [ if state.isJump then play 0 Saw 4096 else const $ pure unit
    ]

main :: Effect Unit
main = do
  asset <- mkAsset [map0] [snd0]
  nemoDev initialState asset defaultDebugConfig

initialState :: State 
initialState = State
  { x: scene.width / 2
  , y: mapSize
  , dy: 0
  , isJump: false
  , appear: LeftWalk
  , frame: 0
  }

walls :: Array E.Emoji
walls = [E.japaneseNoVacancyButton] -- 🈵

map0 :: RawMap
map0 = RawMap """
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈚🈚🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈚🈚🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈵🈵🈵🈵🈳🈳🈳🈳🈳🈳🈳🈳🈵🈵🈵🈵
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈵🈵🈵🈵🈵🈵🈵🈵🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵🈵
"""

snd0 :: RawSound
snd0 = RawSound """
🎼🔈5️⃣🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
🎼🔈5️⃣🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🎹🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳🈳
"""
