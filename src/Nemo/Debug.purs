module Nemo.Debug where

import Prelude

import Data.Int (toNumber)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Graphics.Canvas (fillText, restore, save, setFillStyle, setFont)
import Nemo.Class.Game (class Game, update)
import Nemo.Constants (scene)
import Nemo.Data.Color (colorToCode)
import Nemo.Data.Input (Input)
import Nemo.Data.SpecialInput (SpecialInput)
import Nemo.KeyPress (PressState(..), updatePressState)
import Nemo.Patch.TextBaseline (TextBaseline(..), setTextBaseline)
import Nemo.Types (Asset, DebugConfig, DebugDisplay(..), DrawContext(..), RenderOp)


type DebugInput =
  { input :: Input
  , specialInput :: SpecialInput
  }

type DebugState s =
  { state :: s
  , savedState :: s
  , loopState :: LoopState
  , saveAction :: PressState
  , loadAction :: PressState
  , forwardAction :: PressState
  }

data LoopState = Resume | Suspend | JustSuspend

updateD :: forall s. Game s => DebugInput -> DebugState s -> (Asset -> DebugState s)
updateD i s ass = nnns
  where
    updatedState = update i.input s.state ass
    updatedSaveAction = updatePressState i.specialInput.isSave s.saveAction
    updatedLoadAction = updatePressState i.specialInput.isLoad s.loadAction
    updatedForwardAction = updatePressState i.specialInput.isForward s.forwardAction
    ns = case Tuple s.loopState i.specialInput of
      Tuple Resume { isSuspend: true, isResume: false } -> s { loopState = JustSuspend }
      Tuple Resume _ -> s { state = updatedState }
      Tuple Suspend { isSuspend: false, isResume: true } -> s { state = updatedState, loopState = Resume }
      Tuple Suspend _ -> s
      Tuple JustSuspend { isSuspend: false, isResume: true } -> s { state = updatedState, loopState = Resume }
      Tuple JustSuspend _ -> s { loopState = Suspend }
    nns = case { sa: updatedSaveAction, la: updatedLoadAction, fa: updatedForwardAction } of
      { sa: Catched, la: Catched, fa: _ } -> ns
      { sa: Catched, la: _, fa: Catched } -> ns
      { sa: _, la: Catched, fa: Catched } -> ns
      { sa: Catched, la: _, fa: _ } -> ns { savedState = s.state }
      { sa: _, la: Catched, fa: _ } -> ns { state = s.savedState }
      { sa: _, la: _, fa: Catched } -> ns { state = updatedState }
      _ -> ns
    nnns = nns
      { saveAction = updatedSaveAction
      , loadAction = updatedLoadAction
      , forwardAction = updatedForwardAction
      }

withDebugInput :: Input -> SpecialInput -> DebugInput
withDebugInput i si = { input: i, specialInput: si }

initialDebugState :: forall s. Game s => s -> DebugState s
initialDebugState s =
  { state: s
  , savedState : s
  , loopState: Resume
  , saveAction: Unpressed
  , loadAction: Unpressed
  , forwardAction: Unpressed
  }

providedSave :: forall s. Game s => DebugState s -> Effect Unit -> Effect Unit
providedSave { saveAction: Catched } op = op
providedSave _ op = pure unit

providedUpdate :: forall s. Game s => DebugState s -> Effect Unit -> Effect Unit
providedUpdate { loopState: Resume } op = op
providedUpdate { loopState: Suspend, loadAction: Catched, forwardAction: Catched } op = pure unit
providedUpdate { loopState: Suspend, loadAction: Catched, saveAction: Catched } op = pure unit
providedUpdate { loopState: Suspend, saveAction: Catched, forwardAction: Catched } op = pure unit
providedUpdate { loopState: Suspend, loadAction: Catched } op = op
providedUpdate { loopState: Suspend, forwardAction: Catched } op = op
providedUpdate { loopState: Suspend, saveAction: Catched } op = op
providedUpdate { loopState: JustSuspend } op = op
providedUpdate _ op = pure unit

debugDraw :: forall s. Game s => DebugConfig -> DebugState s -> RenderOp
debugDraw dc ds (DrawContext dctx) = do
  save dctx.ctx
  setFillStyle dctx.ctx (colorToCode dc.color)
  setFont dctx.ctx "bold 64px sans-serif"
  setTextBaseline dctx.ctx BaselineBottom
  case ds.loopState of
    Resume -> fillText dctx.ctx "Resume" 0.0 yBase
    Suspend -> fillText dctx.ctx "Suspend" 0.0 yBase
    JustSuspend -> fillText dctx.ctx "Suspend" 0.0 yBase
  case { sa: ds.saveAction, la: ds.loadAction, fa: ds.forwardAction } of
      { sa: Catched, la: Catched, fa: _ } -> pure unit
      { sa: Catched, la: _, fa: Catched } -> pure unit
      { sa: _, la: Catched, fa: Catched } -> pure unit
      { sa: Catched, la: _, fa: _ } -> fillText dctx.ctx "Saved" xHalf yBase
      { sa: _, la: Catched, fa: _ } -> fillText dctx.ctx "Loaded" xHalf yBase
      { sa: _, la: _, fa: Catched } -> fillText dctx.ctx "Forwarded" xHalf yBase
      _ -> pure unit
  restore dctx.ctx
  where
    xHalf = toNumber scene.width / 2.0
    yBase = case dc.debugDisplay of
      None -> 0.0 -- out of monitor
      LeftTop -> 64.0
      LeftBottom -> toNumber scene.height