local env = std.native('env');
local defaultTag = 'v1.2.5';

{
  tag: env('IMAGE_TAG', defaultTag),
}
