module Main where
import AgarSimu
import Prelude hiding ((.), id)
import Control.Wire

main :: IO ()
main = runSimulation defWorldConsts testScene

testScene :: Scene
testScene = [(derecha, Player (show i) [Bola (20, (20+(fromInteger i)*30)) 200] (rgbColor 255 ((fromIntegral i)*40) 40)) | i <- [0..2]]
         ++ [(super, Player (show i) [Bola (120, (20+(fromInteger (i-2))*50)) 300] (rgbColor 40 ((fromIntegral i)*40) 255)) | i <- [2..3]]

derecha :: AI
derecha = pure (1, 0)

vibrar :: AI
vibrar = for 0.2 . pure (0, 1) --> for 0.2 . pure (0, -1) --> vibrar


derechayesperar :: AI
derechayesperar =  for 0.5 . derecha  --> for 0.5 . pure (0, 0)
                    --> derechayesperar
   
super :: AI
super = (for 1 . pure (1, 1)) --> pure (0.01, 0.01)


