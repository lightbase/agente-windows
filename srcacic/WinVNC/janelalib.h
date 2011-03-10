#ifndef _JANELA_H_
#define _JANELA_H_

class janela (){

public:
	
	janela(string msg);
	virtual ~janela ();

	static BOOL janelaExecuta ();

private:
	UNINT timeout;
}





#endif