Min_Filter :: enum {
    NEAREST;
    LINEAR;
}

Mag_Filter :: enum {
    NEAREST;
    LINEAR;
}

Wrap_Mode :: enum {
    REPEAT;
    CLAMP_TO_EDGE;
}

Texture_Coordinate :: enum {
    U;
    V;
}

Texture :: struct {

    Spec :: struct {
        width: int;
        height: int;
        channels: u32 = 4;
        min_filter: Min_Filter;
        mag_filter: Mag_Filter;
        wrap_mode_u: Wrap_Mode;
        wrap_mode_v: Wrap_Mode;
    }

    id: u32;
    spec: Spec;
}

is_texture_initialized :: inline (using texture: *Texture) -> bool { return id != 0; } 

load_white_texture :: (using texture : *Texture) -> bool {
    using texture.spec;
    width = 1;
    height = 1;
    channels = 4;
    pixels := u8.[ 255, 255, 255, 255 ];
    upload_texture_to_gpu(texture, pixels);
    return true;
}

init_texture :: (texture: *Texture, image: Image, spec: Texture.Spec = .{}) -> bool {
    the_spec := spec;
    the_spec.width  = image.width;
    the_spec.height = image.height;
    return init_texture(texture, the_spec, image.pixels);    
}

init_texture :: (texture: *Texture, spec: Texture.Spec, pixels: [] u8) -> bool {
    if !texture then return false;
    if !pixels.count then return false;
    if spec.width * spec.height * spec.channels != pixels.count then return false;
    if is_texture_initialized(texture) then deinit_texture(texture);
    texture.spec = spec;
    upload_texture_to_gpu(texture, pixels);
    return true;
}

deinit_texture :: (using texture : *Texture) -> bool {
    if id == 0 then return false; 
    glDeleteTextures(1, *id);
    id = 0;
    return true;
}

bind_texture :: (using texture: *Texture, slot: u32 = 0) {
    assert(id != 0);
    glBindTextureUnit(slot, id);
}

#scope_file

upload_texture_to_gpu :: (using texture: *Texture, pixels: [] u8) {
    assert(id == 0);
    using texture.spec;

    data_format: u32 = GL_ZERO;
    internal_format: u32 = GL_ZERO;
    
    if channels == 4 {
        internal_format = GL_RGBA8;
        data_format = GL_RGBA;
    } 
    else if channels == 3 {
        internal_format = GL_RGB8;
        data_format = GL_RGB;
   }

    local_id : u32;
    glCreateTextures(GL_TEXTURE_2D, 1, *local_id);
    id = local_id;
    
    glTextureStorage2D(id, 1, internal_format, xx width, xx height);

    set_min_filter(id, min_filter);
    set_mag_filter(id, mag_filter);

    set_wrap_mode(id, .U, wrap_mode_u);
    set_wrap_mode(id, .V, wrap_mode_v);

    glTextureSubImage2D(id, 0, 0, 0, xx width, xx height, data_format, GL_UNSIGNED_BYTE, pixels.data);
}

set_mag_filter :: (texture_id : u32, mag_filter : Mag_Filter) {
    if mag_filter == {
        case .LINEAR;  glTextureParameteri(texture_id, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        case .NEAREST; glTextureParameteri(texture_id, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
}

set_min_filter :: (texture_id : u32, min_filter : Min_Filter) {
    if min_filter == {
        case .LINEAR;  glTextureParameteri(texture_id, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        case .NEAREST; glTextureParameteri(texture_id, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    }
}

set_wrap_mode :: (texture_id : u32, texture_coordinate : Texture_Coordinate, wrap_mode : Wrap_Mode) {
    coord := ifx texture_coordinate == .U then GL_TEXTURE_WRAP_S else GL_TEXTURE_WRAP_T;
    if wrap_mode == {
        case .REPEAT; glTextureParameteri(texture_id, cast(u32) coord, GL_REPEAT);
        case .CLAMP_TO_EDGE; glTextureParameteri(texture_id, cast(u32) coord, GL_CLAMP_TO_EDGE);
    }
}