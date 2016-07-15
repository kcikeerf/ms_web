/**
 * Title:CKEditor在线编辑器的代码插入插件
 * Author:铁木箱子(http://www.mzone.cc)
 * Date:2010-07-21
 */
(function () {
	CKEDITOR.wordContentCallback = function(html){
		var button1 = $(".cke_dialog_tab:first-child").not(":hidden").attr("id");

		$("#"+button1).addClass("cke_dialog_tab_selected").siblings().removeClass("cke_dialog_tab_selected");
		$("[aria-labelledby="+button1).show().attr("aria-hidden","false").siblings().hide().attr("aria-hidden","true");
		$(".word_content").html(html);
	}
    function HelloWorldDialog(editor) {

        return {
            title: '上传word文件',
            minWidth: 300,
            minHeight: 120,
            buttons: [
            	CKEDITOR.dialog.okButton,
            	CKEDITOR.dialog.cancelButton
            ],
            contents: [
                {
                    id: 'callBackHtml',
                    label: '内容',
                    title: '内容',
                    elements: [
                        {
                            id: 'wordContent',
                            type: 'html',
                            html:'<div class="word_content"></div>',
                            style: 'position: absolute;right: 6px;left: 6px;top: 80px;bottom: 47px;overflow:auto;border:1px solid #ccc;padding:3px;',
                            'default': '',
                            required: true,
                            commit: function () {
                              	var text = $(".word_content").html();
                               	var element = new CKEDITOR.dom.element('div', editor.document);
                               	element.setHtml(text);
                               	editor.insertElement(element);
                            }
                        }
                    ]

                },
                {
                    id: 'wordUpload',
                    label: '上传',
                    title: '上传',
                    elements: [
                        {
                            id: 'word_upload',
                            type: 'html',
                            html:'<iframe class="word_iframe" frameborder="0" allowtransparency="0" role="presentation" title="上传到服务器" src="/assets/editor/ckeditor/plugins/wordUpload/upload.html"></iframe>',
                            style: 'width: 100%;',
                            'default': '',
                            required: true
                        }
                    ]

                }
            ],
            onLoad: function () {
                //alert('onLoad');
            },
            onShow: function () {
                $(".word_content").html("");
                $(".word_iframe").contents().find(".wordUpload").val("");
            },
            onHide: function () {
                //alert('onHide');
            },
            onOk: function () {
                this.commitContent();
            },
            onCancel: function () {
                //alert('onCancel');
            },
            resizable: CKEDITOR.DIALOG_RESIZE_HEIGHT
        };
    }
    CKEDITOR.dialog.add('wordUpload', function (editor) {
        return HelloWorldDialog(editor);
    });

})();
