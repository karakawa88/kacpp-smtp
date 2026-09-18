import requests
import sys
from bs4 import BeautifulSoup

""" URLのHTMLからCSSセレクタで要素の文字列を取得して標準出力に書き出すスクリプト。
URLのHTMLを取得してCSSセレクタで指定してその要素を取得するがURLと
CSSセレクタは文字列で引数で指定する。第一引数はURLで第二引数がCSSセレクタである。
ステータスコード:
    0       正常
    1       HTMLが取得できなかった
    2       CSSセレクタで要素の文字列が取得できなかった。
"""

url = sys.argv[1]
"""str: URL
HTMLを取得するURL。
"""
cssselect = sys.argv[2]
"""str: CSSセレクタ文字列
要素の文字列を取り出すCSSセレクタ。
"""
headers = {
    'User-Agent': 'PythonRequestsClawler'
}
"""str: HTTP GETのヘッダー
User-Agentが設定されている。
これはこれが設定されていないとHTML取得に失敗する場合もあるため。
"""


def fetch_html(url):
    """URLからHTMLを取得して返す。
    引数のURLからHTMLを取得してHTMLを返す。
    Args:
        url str: URL文字列
    Returns:
        str: HTML文字列
    Examples:
        html = fetch_html(url)
    """
    res = None
    try:
        
        res = requests.get(url, headers=headers)
        print(res)
        res.raise_for_status()
        return res.text
    except requests.exceptions.RequestException as ex:
        print(f"Error HTMLファイル取得時エラー URL={url}", 
                file=sys.stderr)
        return None

def cssselect_get(html, cssselect):
    """HTML文字列からCSSセレクタで選択した要素のコンテンツを返す。
    引数のHTML文字列のHTMLからCSSセレクタの要素のコンテンツを返す。
    Args:
        html str: HTML文字列
        cssselect str: CSSセレクタ文字列
    Returns:
        str: 選択した要素のコンテンツ
    Examples:
        html = "<html> ... </html>"
        text = cssselect_get(html, "#id pre")
    """
    bsoup = BeautifulSoup(html, 'lxml')
    element = bsoup.select_one(cssselect)
    if element is None:
        return ""
    text = element.get_text()
    return text.strip()

def main():
    """メイン処理
    URLからHTMLを取得。CSSセレクタでHTMLから要素のコンテンツを取得。
    それを標準出力に書き出す。
    """
    html = fetch_html(url)
    if html is None:
        sys.exit(1)
    text = cssselect_get(html, cssselect)
    if text is None:
        print(f"Error CSSセレクタから文字列を取得できませんでした。 {cssselect}",
                file=sys.stderr)
        sys.exit(2)
    print(text)

if __name__ == '__main__':
    main()
    sys.exit(0)

