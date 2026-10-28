local env = std.native('env');
local defaultTag = 'v1.0.1';

{
  tag: env('IMAGE_TAG', defaultTag),
}
