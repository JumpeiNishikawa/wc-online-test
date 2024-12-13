const path = require('path');
const fs = require('fs');

function getNumOfExp(expdate){
    let fileCount = 0;
    const basepath = path.resolve(__dirname, "expLog");
    const allFiles = fs.readdirSync(basepath);

    allFiles.forEach((file) => {
        const filePath = path.join(basepath, file);
        let stats = fs.statSync(filePath);

        if(stats.isFile() && stats.birthtime > expdate){
            fileCount++;
        }
    });

    console.log("allFiles[0]:", allFiles[0]);
    console.log("allFiles:", allFiles.length, ", files after", expdate, ":", fileCount);
    return fileCount;
}

let date=new Date("2024-1-1");
let fc = getNumOfExp(date);
console.log(fc);