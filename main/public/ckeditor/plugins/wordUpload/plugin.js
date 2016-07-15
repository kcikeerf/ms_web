/**
 
 */
CKEDITOR.plugins.add('wordUpload', {
    init: function(editor){
        var pluginName = 'wordUpload';
        CKEDITOR.dialog.add(pluginName, this.path + 'dialogs/wordUpload.js');
        editor.addCommand(pluginName, new CKEDITOR.dialogCommand(pluginName));
        editor.ui.addButton(pluginName, {
            label: "上传word文件",
            command: pluginName,
            icon: this.path + 'images/wordUpload.png'
        });
        CKEDITOR.dialog.add(pluginName, this.path + 'dialogs/wordUpload.js');
    }
});