import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const files=['README.md',...fs.readdirSync(path.join(root,'docs')).filter(name=>name.endsWith('.md')).map(name=>`docs/${name}`)];
const docsIndex=fs.readFileSync(path.join(root,'docs/README.md'),'utf8');
let failures=0;

function fail(message){console.error(message);failures+=1;}

for(const relative of files){
  const full=path.join(root,relative);
  const text=fs.readFileSync(full,'utf8');
  if(!/^#\s+\S/m.test(text))fail(`${relative}: missing top-level heading`);
  const linkPattern=/\[[^\]]+\]\(([^)]+)\)/g;
  for(const match of text.matchAll(linkPattern)){
    const target=match[1].trim();
    if(!target||/^(https?:|mailto:|#)/i.test(target))continue;
    const clean=decodeURIComponent(target.split('#')[0]);
    if(!clean)continue;
    const resolved=path.resolve(path.dirname(full),clean);
    if(!resolved.startsWith(root+path.sep)&&resolved!==root){fail(`${relative}: local link escapes repository: ${target}`);continue;}
    if(!fs.existsSync(resolved))fail(`${relative}: broken local link: ${target}`);
  }
}

for(const relative of files.filter(file=>file.startsWith('docs/')&&file!=='docs/README.md')){
  const basename=path.basename(relative);
  if(!docsIndex.includes(`(${basename})`))fail(`docs/README.md: missing link to ${basename}`);
}

const readme=fs.readFileSync(path.join(root,'README.md'),'utf8');
if(!/reference architecture/i.test(readme))fail('README.md: repository boundary must identify this as a reference architecture');
if(!/not.*production|not.*deployment|scaffold/i.test(readme))fail('README.md: implementation boundary must remain explicit');

if(failures)process.exit(1);
console.log(`Validated ${files.length} architecture/operations Markdown files.`);
