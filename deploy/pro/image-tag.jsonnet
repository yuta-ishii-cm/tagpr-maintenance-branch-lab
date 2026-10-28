local env = std.native('env');
local defaultTag = 'v1.1.2';

{
  tag: env('IMAGE_TAG', defaultTag),
}
