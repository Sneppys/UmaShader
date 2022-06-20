# UmaShader
Simple VRChat-ready Uma Musume styled Unity shader using original game textures

* Note: This is **not complete**. There are some edge cases to work out and some rendering features are still missing or not working properly.

# Example
![Example Image](https://user-images.githubusercontent.com/4298508/174686400-4ac30a78-9c23-40c0-975c-cba5626f5a3e.png)

# Shaders

- Base (+alpha): Basic look of the shader, mostly used for the body and hair. Requires "base" and "ctrl" texture maps. The alpha version is used for anything that requires semitransparency (like glasses).
- Face: Used for the face. Similar to the Base shader, but with different texture maps and different lighting. No outlines yet as they do not play well with the eyes and mouth.
- Eye: Used for the eyes. Currently uses a modified UV setup so may require editing the model to get the eyes to show up correctly. Has sliders for the different eye highlights so they can be animated, as well as a way to change which eye texture is used.
- Tail: Similar look of the Base shader for the tails, but requires less texture maps as most tails do not have "base" or "ctrl" maps.
- Cheek: Used for the cheek mesh. Adds the blush around the face, and has sliders to allow animation between the blush textures and their intensity. 
