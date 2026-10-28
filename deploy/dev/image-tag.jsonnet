local env = std.native('env');
local defaultTag = 'v1.2.0';

{
  tag: env('IMAGE_TAG', defaultTag),
}
