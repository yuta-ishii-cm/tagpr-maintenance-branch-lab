local env = std.native('env');
local defaultTag = 'v1.4.0';

{
  tag: env('IMAGE_TAG', defaultTag),
}
