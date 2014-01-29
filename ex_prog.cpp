#include <iostream>
#include <sstream>

using namespace std;

int main(){
  stringstream ss;
  char ch;
  cin >> noskipws;
  cin >> ch;
  while (!cin.fail()){
    ss << ch;
    cin >> ch;
  }
  cout << ss.str() << endl;
  return 0;
}
