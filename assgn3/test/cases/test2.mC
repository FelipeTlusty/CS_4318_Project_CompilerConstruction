int a;
int b;
void err1(int x, int y){
    x = x + y;
}
int arr1[10];
void func(){
    /* nothing to see here */
}

int main(){
    int c;
    c = 2 + 3;
    func();
    a = 3;
    b = 2 * 3;
    err1(a, a);
    err1(a, b);
    a = c;
    a = arr1[2];
    b = arr1[1];
    err1(b, a);
    a = arr1[8];

    return 0;
}