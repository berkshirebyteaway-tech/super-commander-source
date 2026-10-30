export function shipSource(text) {
  if (/\[=*\[/.test(text) || /\\\r?$/m.test(text)) return text;
  return text.split('\n').map(line => /^\s*--/.test(line) ? '' : line).join('\n');
}
export const shippedRuntime = ['MultiplayerServer.server.luau', 'NativeExperience.client.luau', 'LoadingScreen.client.luau'];
