local env = std.native('env');
local defaultTag = 'v1.3.0';

{
  tag: env('IMAGE_TAG', defaultTag),
}
